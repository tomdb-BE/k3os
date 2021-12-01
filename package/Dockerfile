FROM scratch
COPY build/rke2os/system/ /rke2os/system/
ENV PATH /rke2os/system/rke2os/current:/rke2os/system/rke2/current:${PATH}
ENTRYPOINT ["rke2os"]
CMD ["help"]
